package com.oneplustvlauncher;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.oneplustvlauncher.utils.AppInfo;

import java.util.List;

public class DockAdapter extends RecyclerView.Adapter<DockAdapter.VH> {

    public interface OnFocusListener {
        void onDockFocused(AppInfo app, View itemView, int position);
    }

    public interface OnClickListener {
        void onDockClicked(AppInfo app);
    }

    private final List<AppInfo> mApps;
    private OnFocusListener mFocusListener;
    private OnClickListener mClickListener;

    public DockAdapter(List<AppInfo> apps) {
        this.mApps = apps;
    }

    public void setFocusListener(OnFocusListener l) { mFocusListener = l; }
    public void setClickListener(OnClickListener l) { mClickListener = l; }

    @NonNull
    @Override
    public VH onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View v = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_dock_tile, parent, false);
        return new VH(v);
    }

    @Override
    public void onBindViewHolder(@NonNull VH holder, int position) {
        AppInfo app = mApps.get(position);
        holder.banner.setImageDrawable(app.banner);
        holder.name.setText(app.label);

        holder.itemView.setOnFocusChangeListener((v, hasFocus) -> {
            if (hasFocus) {
                holder.itemView.animate().scaleX(1.15f).scaleY(1.15f).setDuration(150).start();
                holder.name.setVisibility(View.VISIBLE);
                if (mFocusListener != null) mFocusListener.onDockFocused(app, holder.itemView, position);
            } else {
                holder.itemView.animate().scaleX(1f).scaleY(1f).setDuration(150).start();
                holder.name.setVisibility(View.INVISIBLE);
            }
        });

        holder.itemView.setOnClickListener(v -> {
            if (mClickListener != null) mClickListener.onDockClicked(app);
        });
    }

    @Override
    public int getItemCount() { return mApps.size(); }

    static class VH extends RecyclerView.ViewHolder {
        ImageView banner;
        TextView name;
        VH(@NonNull View v) {
            super(v);
            banner = v.findViewById(R.id.app_banner);
            name = v.findViewById(R.id.app_name);
        }
    }
}
